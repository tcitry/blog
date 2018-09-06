---
layout: page
title: 标签
---

<h2>目录</h2>
<ul>
    {% for tag in site.tags %}
    <li>
        <p><a href="#{{ tag | first }}" title="view allposts">{{ tag | first }}({{ tag | last | size }})</a></p>
    </li>
    {% endfor %}
</ul>

{% for tag in site.tags %}

<h4 id="{{ tag | first }}">{{ tag | first }}</h4>
<ul>
    {% for post in tag.last %}
        <li>
            <p>{{ post.date | date: "%Y-%m-%d" }} <a href="{{ post.url }}">{{ post.title }}</a></p>
        </li>
    {% endfor %}
</ul>
{% endfor %}