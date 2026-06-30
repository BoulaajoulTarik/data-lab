FROM squidfunk/mkdocs-material:9.6.20 AS build
WORKDIR /docs
COPY mkdocs.yml .
COPY docs ./docs
RUN mkdocs build

FROM nginx:1.30.3-alpine
COPY --from=build /docs/site /usr/share/nginx/html
