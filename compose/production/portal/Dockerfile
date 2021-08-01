FROM nginx:1.21.1-alpine

ADD run.sh /run.sh
ADD default.conf /etc/nginx/conf.d/default.conf

RUN chmod +x /run.sh

CMD ["/run.sh"]