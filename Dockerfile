FROM node AS bundler
WORKDIR /worker
COPY . .

RUN npx webpack --mode production

FROM swift AS builder
WORKDIR /worker
COPY --from=bundler /worker .

RUN swift build -c release

RUN export BIN_PATH=$(swift build -c release --show-bin-path)
RUN mkdir release && cp -r $BIN_PATH/ release/

FROM swift:slim
WORKDIR /app
COPY --from=builder /worker/release .

ENTRYPOINT ["./DBBrowser"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]