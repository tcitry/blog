---
layout: page
title: 分类
---

<h2>目录</h2>
<ul>
    {% for category in site.categories %}
    <li>
        <p><a href="#{{ category | first }}" title="view allposts">{{ category | first }}({{ category | last | size }})</a></p>
    </li>
    {% endfor %}
</ul>

{% for category in site.categories %}

<h4 id="{{ category | first }}">{{ category | first }}</h4>
<ul>
    {% for post in category.last %}
        <li>
            <p>{{ post.date | date: "%Y-%m-%d" }} <a href="{{ post.url }}">{{ post.title }}</a></p>
        </li>
    {% endfor %}
</ul>
{% endfor %}