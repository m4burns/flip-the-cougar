FROM m4burns/racket:latest

RUN apk add --no-cache libedit && \
  raco pkg install --auto --batch \
    typed-racket \
    aws \
    xrepl \
    rfc6455 \
    || true

CMD ["racket", "-il", "xrepl"]
