Campaign Link Tracking Endpoint
====

Application for providing an endpoint for campaign link click tracking.
Events are then passed off to redis for storage in kafka. Some other
features of note:

- SSL Termination is done by the application
- Load balancing can be easily done by increasing the number of dynos
- Geoip and device detection are explicitly not done. These are subsequently
  handled by the [kafkastore](https://github.com/adtekio/kafkastore)
- Event type is [always](https://github.com/adtekio/tracking.clicks/blob/985520904bf22b600edf45f21626430b1ae08d60/lib/click_handler.rb#L126) ```click```.
- Kafka topic is [always](https://github.com/adtekio/tracking.clicks/blob/985520904bf22b600edf45f21626430b1ae08d60/lib/click_handler.rb#L126) ```clicks```.
- Handles redirects to the various application stores.

This application has the same purpose as the
[in-app tracker](https://github.com/adtekio/tracking.inapp) but also
handles redirects to application stores (i.e. google and apple).

Storage of events to kafka is later handled by the
[kafkastore](https://github.com/adtekio/kafkastore).

Campaign links defined in the [analytics](https://github.com/adtekio/analytics)
tool determine where clicks are redirected to.

### Redis storage

The string that is pushed to redis is structured as follows (all values
are separeted by a single space):

```
"%s %i clicks /t/click %s %s" % [ip,
                                 Time.now.to_i,
                                 click.parameters,
                                 request.user_agent]
```

1. Request IP which is later converted to a country by the kafkastore
   using geoip lookup.
2. Timestamp in seconds since epoch when the request was recieved by the
   tracker.
3. Kafka topic to store the message. This is always ```clicks```.
4. Event type which always ```click```.
5. Click paramters that a [combination](https://github.com/adtekio/tracking.clicks/blob/985520904bf22b600edf45f21626430b1ae08d60/lib/click_handler.rb#L108-L123) of campaign link details and
   the click that was made.
6. User agent is appended to the end. This the later converted to device
   information by the [kafkastore](https://github.com/adtekio/kafkastore/blob/a9e3670011c71fcc669a46e62df95d06683cae79/lib/batch_worker.rb#L27). Note: the user agent
   can contain spaces, the user agent is assumed to be everything after query
   string.

If this format should change, then the [kafkastore](https://github.com/adtekio/kafkastore/blob/a9e3670011c71fcc669a46e62df95d06683cae79/lib/batch_worker.rb#L26-L42)
needs updating, along with the [in-app tracker](https://github.com/adtekio/tracking.inapp/blob/448d1b81b921bf77896a467e15358bc6f022cc56/routes/tracking.rb#L11-L15).

### Redirect Handling

Redirection to the applicable application store is done based on the platform
of the device making the request. This is of course, in certain senses, an
approximation but can be [easily changed](https://github.com/adtekio/tracking.clicks/blob/985520904bf22b600edf45f21626430b1ae08d60/lib/click_handler.rb#L133-L140) if reality changes.

## Deployment

Easiest way to deploy this, is to use heroku!

[![Deploy To Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/adtekio/tracking.clicks)

## Testing locally

Generate a ```.env``` and then fill it with values:

    prompt> rake appjson:to_dotenv
    prompt> $EDITOR .env

First setup a test database:

    prompt> RACK_ENV=test rake db:create
    prompt> RACK_ENV=test rake db:migrate

This will the database used in development but the database name will have
a [postfix](https://github.com/adtekio/tracking.clicks/blob/master/Rakefile)
of ```_test```.

Then run the tests:

    prompt> rake

Should all pass!

## Starting locally

Generate a ```.env``` and then fill it with values:

    prompt> rake appjson:to_dotenv
    prompt> $EDITOR .env

Start the application:

    prompt> foreman start
