FROM m4burns/ftc-base:latest

COPY ./server.rkt ./
RUN raco make server.rkt

EXPOSE 8080
CMD ["racket", "server.rkt"]
