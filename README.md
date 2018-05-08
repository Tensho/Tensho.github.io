### Run

    $ docker build . -t tensho.github.io
    $ docker run --rm -p 4000:4000 -v $PWD:/blog tensho.github.io

### TODO

- Add post excerpts
- Fit images to the section width
- Check spelling and punctuation automatically
- Jekyll doesn't convert links to anchor tags (`<a>`)
- Add photo
