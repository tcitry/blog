---
title: 浅谈Django-REST-framework的设计与源码
layout: post
category: Django
tag: [Django, Django-Rest-Framework]
---

从一年半之前接触Django，一年前接触Django-REST-framework（后称drf），再后来中间有个空挡，一直没有真正用到drf。由于当时各方面的素质比较差，理解restful和drf的设计很吃力，记得很清楚，还是在实习的时候，看个drf的英文文档要看好几遍，结果还是有很多概念看不明白，最后还是硬着头皮死记硬背地使用。最近又重新接触到，翻看文档发现，当时很难理解的东西，如今看一遍就懂了，顺带看了源码，也比较容易理解，至少比Django的源码简单不少。

下面开始从drf的设计和源码两个方面，结合自己的看法，谈谈drf。

## APIView

APIView是drf概念体系中最基本类视图，它基于Django的View，同时又实现了一层对自己创造的概念的封装，比如`permission_classes`，`render_classes`，`authentication_classes`等，相当于请求过来后又进入一层，过滤（验证、初始化）完要走的这些classes，才能执行到我们自己实现的view。

## Mixin

在介绍Generic view前先说一下mixin。说白了，官方给的案例里面的mixin，就是对model的object增删改查的原子操作。比如`RetrieveModelMixin`，通过get_object先获取到对象，然后通过serializer拿到序列化数据。

```python
class RetrieveModelMixin(object):
    """
    Retrieve a model instance.
    """
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
```

延伸开来，Mixin是一个非常重要的概念，因为它是模块化拆分后最关键的原子逻辑实现，是每一个单独的块。试想下，我们可以通过这些小块拼接成不同的功能，比如用户注册功能，使用者有可能在手机注册，有可能在web注册，在Django后端中可能需要提供两套view层接口，甚至还有渲染template的实现，但是真正的逻辑处理上，可以只调用一个`RegistMixin`的东西，从而提高代码复用，降低维护成本。

甚至，Mixin可以重写同时继承的GenericAPIView中的实现，比如request参数处理，Response数据处理（视频、文件格式之类），get_queryset，get_serializer等等有通用需求，并且会在多个地方复用的定制，比如根据传入参数指定需要的serializer从而在mixin中重写get_serializer方法的实现逻辑。总之，原本会在View中发生的一切，都可以通过Mixin封装起来，或重写、或新的逻辑实现。

## Generic views

典型的Generic view就是这样的，本质上是类视图，它由一些Mixin组成，这里的`ListModelMixin`实现了list()方法，并同时继承自`GenericAPIView`，同时自己实现了由get()到list()的转发。复杂的是，`GenericAPIView`实现，以及他的执行过程，和后期对里面函数的重写、定制。所以抽时间多研究下这里很值得，以后也会节省大量时间。

```python
class ListAPIView(mixins.ListModelMixin,
                  GenericAPIView):
    """
    Concrete view for listing a queryset.
    """
    def get(self, request, *args, **kwargs):
        return self.list(request, *args, **kwargs)
```

如果要实现的逻辑不是很复杂的话，直接在view中继承一个`[List[Create[Update]]]APIView`，然后指定下`serializer_class`，`permission_class`，`queryset`等就可以了。对drf熟悉的话相信这种方式实现功能会很快。

## Viewsets

先看代码，ViewSet继承了`ViewSetMixin`和`APIView`，`ViewSetMix`是`APIView`中`as_view`的重写，实现请求到action的转发，虽然Django自带的View也实现了as_view，但只是传递初始化参数，确实没有这个请求转发到action的实现，APIView里面也没有。这里也可以学习到：Python的多重继承中，子类形参的先后顺序，影响到执行的是哪个类中的`as_view`方法，相当于`ViewSetMixin`又继承了`APIView`。

```python
class ViewSet(ViewSetMixin, views.APIView):
    """
    The base ViewSet class does not provide any actions by default.
    """
    pass
```

viewsets和APIView不一样的地方在于，它要表达的更多的是一个方法视图的集合，他的内部是已经实现了的`list()`，`retrieve()`，`delete()`，`update()`的实现，如果实现用drf的DefaultRouter。router和as_view都可以实现GET请求-->list()的转发，值得一提的还有`detail_route`和`list_route`，他们需要在urls中配置router的前提下使用，在Router类的`get_url`里面的`get_routers`执行，然后获得所有的路由列表，再进行action转发。

```python
# account/views.py
class AccountViewSet(viewsets.ModelViewSet):
    """
    对Account的操作的集合，本质上是基于方法视图的封装
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @detail_route(methods=['post'], url_path='change-password')
    def set_password(self, request, *args, **kwargs):
        """
        修改用户的密码
        """
        return Response(status=status.HTTP_200_OK)

    @detail_route(methods=['post'], url_path='change-username')
    def change_username(self, request, *args, **kwargs):
        """
        修改用户的用户名
        """
        return Response(status=status.HTTP_200_OK, data={'msg': 'changed'})

# account/urls.py
router = routers.SimpleRouter()
router.register(r'', views.AccountViewSet, base_name='user')
urlpatterns = router.urls

```
![](/image/account_url_list.png)

以上代码，直接实现了对account的增（create）删（delete）改（update）和account列表（list），同时我又添加了`set_password`和`change_username`方法。这种形式没接触过的话很难理解，但是却很实用，尤其一个model有频繁的不同功能需求的时候，如果写`SetPasswordView`和`ChangeUsernameView`这样类视图的实现，未免会很麻烦，这个时候viewsets就是很好的选择。

## Serializers

```python
class TopicListSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.TopicModel
        fields = '__all__'
        read_only_fields = ('id', 'author_id')
```

Serializer相当于View和Model的中间层，避免view频繁直接操作model object的同时，规范数据字段格式、内容、validator、提供序列化数据等等，同时可以定义方法实现对model的特定操作。serializer不适合处理业务逻辑，它要做的就是对数据传入传出的处理，保证数据正确。通常为了验证和序列化各项数据，serializer的代码加上validator也集中了较大的工作量。

## 其它

drf最主要的就是上面提到的一些概念，也许在刚接触Django Web的话没有接触过，但是这应该是drf中最常用的。其他的比如router、Throttling、validator也比较实用，甚至也是必须掌握的，但是drf的文档写的确定很详细，使用方法不再介绍。

## 总结

我的理解，drf是基于“Don't repeat yourself”原则，提出一个Web开发的规范，它代码里提供了规范的接口，和最基础的使用例子，而在实际的复杂逻辑开发中，需要的是对各种概念的“custome”定制，几乎文档每一页都提供了定制的介绍。实际的应用里面不会是简单的增删改查，而是需要走一定的逻辑处理后的增删改查，同时还有对基础操作频繁的复用。drf通过把web业务系统中会出现的每一步流程拆分，进行模块化，概念化，让开发者知道需要开发的业务属于哪一种概念，放到哪一个模块下面，从而在drf的大框架下特定的位置编写，这样减少了一份功能多份代码实现的麻烦，也因为规范化coding提高了开发者的效率。

当然drf也有缺点，它对新手不够友好，一些封装太极致，以至于不容易明白程序的执行流程，比如我初次看`viewsets`、`GenericAPIView`的时候。

最后我基于drf的文档，学习过程中写了一个论坛demo：[drforum](https://github.com/tcitry/drforum)的论坛例子，可以直接runserver调试。通过`127.0.0.1:8000/docs`可以查看汇总的接口，这里使用了[DRF Docs](http://drfdocs.com/)。

