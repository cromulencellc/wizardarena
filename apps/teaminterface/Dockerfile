FROM elixir:1.3.2

RUN apt-get update && \
  apt-get install -y postgresql-client && \
  curl -sL https://deb.nodesource.com/setup_6.x | bash -;\
  apt-get install -y nodejs
RUN mkdir -p /apps/teaminterface

COPY mix.exs mix.lock /apps/teaminterface/
COPY package.json /apps/teaminterface/

WORKDIR /apps/teaminterface

RUN mix local.hex --force
RUN mix deps.get
RUN mix deps.compile
RUN npm install

COPY . /apps/teaminterface
