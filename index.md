<a href="about">Кем я себя возомнил?</a>

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <p><time datetime="{{ post.date | date: "%Y-%m-%d" }}">{{ post.date | date: "%d/%m/%Y" }}</time></p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
