### Run

    $ bundle exec jekyll serve

### Run with Docker

    $ docker build . -t tensho.github.io
    $ docker run --rm -p 4000:4000 -v $PWD:/blog tensho.github.io
    
### Check GitHub Pages Versions 

    $ bundle exec github-pages versions
    
### Test

    $ bundle exec htmlproofer ./_site --assume_extension \
                                      --disable_external \
                                      --check_external_hash \
                                      --check_html \
                                      --check_favicon \
                                      --check_opengraph \
                                      --check_img_http
                                      
    
### Jekyll

- [Gem-base themes](https://jekyllrb.com/docs/themes/#understanding-gem-based-themes)
- [Check GitHub Pages gem versions](https://pages.github.com/versions)

### TODO

- [CI] Add `html-proofer`
- Add post excerpts
- Fit images to the section width
- [CI] Check spelling and punctuation automatically
- Jekyll doesn't convert links to anchor tags (`<a>`)
- Add photo
