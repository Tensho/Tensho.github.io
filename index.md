---
layout: default
pagination: 
  enabled: true
---

<ul>
  {% for post in paginator.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <p><time datetime="{{ post.date | date: "%Y-%m-%d" }}">{{ post.date | date: "%d/%m/%Y" }}</time></p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

{% if paginator.total_pages > 1 %}
<style>
  ul.pagination {
    text-align: center;
  }
   
  ul.pagination li {
    display: inline;
    border: 1px solid black;
    padding: 10px;
    margin: 5px;
  }
</style>

<ul class="pagination">

  {% if paginator.previous_page %}
  <li>
    <a href="{{ paginator.previous_page_path | prepend: site.baseurl }}">&lt;&lt;</a>
  </li>
  {% endif %}
  
  {% if paginator.page_trail %}
    {% for trail in paginator.page_trail %}
      <li {% if page.url == trail.path %}class="selected"{% endif %}>
          <a href="{{ trail.path | prepend: site.baseurl }}">{{ trail.num }}</a>
      </li>
    {% endfor %}
  {% endif %}
  
  {% if paginator.next_page %}
  <li>
    <a href="{{ paginator.next_page_path | prepend: site.baseurl }}">&gt;&gt;</a>
  </li>
  {% endif %}
  
</ul>
{% endif %}
