### Run

    $ bundle exec jekyll serve

### Run with Docker

    $ docker build . -t tensho.github.io
    $ docker run --rm -p 4000:4000 -v $PWD:/blog tensho.github.io
    
### `github-pages`

- https://pages.github.com/versions

    $ bundle exec github-pages versions
    
### Jekyll

- [Gem-base themes](https://jekyllrb.com/docs/themes/#understanding-gem-based-themes)

### TODO

- Add post excerpts
- Fit images to the section width
- Check spelling and punctuation automatically
- Jekyll doesn't convert links to anchor tags (`<a>`)
- Add photo
