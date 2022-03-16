FROM node:14-alpine as deps
RUN apk --no-cache add git
WORKDIR /calcom
RUN git clone --recursive https://github.com/michael-dm/calcom-docker.git . 
COPY calendso/apps/web/package.json calendso/apps/web/yarn.lock ./
COPY calendso/packages/prisma prisma
# RUN yarn install --frozen-lockfile
RUN yarn install

FROM node:14 as builder

WORKDIR /calcom
ARG BASE_URL
ARG NEXT_PUBLIC_APP_URL
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_TELEMETRY_KEY 
ENV BASE_URL=$BASE_URL \
    NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
    NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    NEXT_PUBLIC_TELEMETRY_KEY=$NEXT_PUBLIC_TELEMETRY_KEY
    
COPY calendso/apps/web ./apps/web
COPY calendso/packages ./packages
COPY --from=deps /calcom/node_modules ./apps/web/node_modules
WORKDIR /calcom/apps/web
RUN yarn build && yarn install --production --ignore-scripts --prefer-offline

FROM node:14 as runner
WORKDIR /calcom
ENV NODE_ENV production

COPY --from=builder /calcom/apps/web/node_modules ./node_modules
COPY --from=builder /calcom/apps/web/prisma ./prisma
COPY --from=builder /calcom/apps/web/scripts ./scripts
COPY --from=builder /calcom/apps/web/next.config.js ./
COPY --from=builder /calcom/apps/web/next-i18next.config.js ./
COPY --from=builder /calcom/apps/web/public ./public
COPY --from=builder /calcom/apps/web/.next ./.next
COPY --from=builder /calcom/apps/web/package.json ./package.json
COPY  scripts scripts

EXPOSE 3000
CMD ["/calcom/scripts/start.sh"]
