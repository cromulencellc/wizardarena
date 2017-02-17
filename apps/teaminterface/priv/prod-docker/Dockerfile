FROM teaminterface

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=DacWakwyoshapCamaicMocenlaf#owfokhordEdcivicnikounvigdolgabdovPheyrowarogNeyGrisyeOm#okcuvNehiafExpydvitvimDunWofOcjomGeemWustob
ENV DATABASE_URL=postgres://engine:labrat@master1:5432/teaminterface_dev

RUN mix deps.get
RUN npm install
RUN node node_modules/brunch/bin/brunch build
RUN mix compile
RUN mix phoenix.digest

CMD mix phoenix.server
