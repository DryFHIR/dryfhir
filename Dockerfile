FROM openresty/openresty:latest-xenial
RUN apt-get update -qq && apt-get install -qqy libssl-dev
RUN /usr/local/openresty/luajit/bin/luarocks install lapis && \
/usr/local/openresty/luajit/bin/luarocks install penlight && \
/usr/local/openresty/luajit/bin/luarocks install inspect
