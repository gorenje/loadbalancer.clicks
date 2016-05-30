Click Tracking
========

Click load balancer. Used to store clicks to redis (for the
[kafkastore](https://github.com/adtekio/kafkastore) to put into kafka).
Campaign links defined in the [analytics](https://github.com/adtekio/analytics)
tool determine where clicks are redirected to.

## Deployment

[![Deploy To Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/adtekio/tracking.clicks)

## Setup & Testing locally

To start the server:

    foreman start
