const express = require('express');
const app = express();
const path = require('path');
const { Temporal } = require('@js-temporal/polyfill');
const client = require('prom-client');


app.use(express.static('./'));
const register = new client.Registry();

//  * CREATES A NEW OBJECT CONTAINING THE METRICS LABEL NAMES
const metric_label_enum = {
  PATH: "path",
  METHOD: "method",
  STATUS_CODE: "status_code",
};
// * CREATES A NEW CLASS FOR ASSIGNING LABELS TO VARIOUS METRICS
class MetricLabelClass {
  constructor(method, pathname, statusCode) {
    this.method = method;
    this.path = pathname;
    this.status_code = statusCode;
  }
}

// * The http_request counter for measuring the total no of requests made to the application
const gandalf_request_total = new client.Counter({
  name: "node_gandalf_request_total",
  help: "The total number of GET requests received at /gandalf",
  labelNames: [
    metric_label_enum.PATH,
    metric_label_enum.METHOD,
    metric_label_enum.STATUS_CODE,
  ],
});

// * Registers the HTTP request counter metric
register.registerMetric(gandalf_request_total);

const colombo_request_total = new client.Counter({
  name: "node_colombo_request_total",
  help: "The total number of GET requests received at /colombo",
  labelNames: [
    metric_label_enum.PATH,
    metric_label_enum.METHOD,
    metric_label_enum.STATUS_CODE,
  ],
});

register.registerMetric(colombo_request_total);

app.set('view engine', 'ejs');

app.use((req, res, next) => {
  // Get's the Req URL object
  const req_url = new URL(req.url, `http://${req.headers.host}/gandalf`);

  // Copies the original res.send function to a variable
  const original_res_send_function = res.send;

  // Creates a new send function with the functionality of ending the timer, and incrementing the gandalf_request_total metric whenever the response.send function is called
  const res_send_interceptor = function (body) {
    // Increment the gandalf_request_total metric
    if (req_url.pathname === '/gandalf') {
      gandalf_request_total.inc(
        new MetricLabelClass(req.method, req_url.pathname, res.statusCode)
      );
    }
    else if (req_url.pathname === '/colombo') {
      colombo_request_total.inc(
        new MetricLabelClass(req.method, req_url.pathname, res.statusCode)
      );
    }
    // Calls the original response.send function
    original_res_send_function.call(this, body);
  };

  // Overrides the existing response.send object/property with the function defined above
  res.send = res_send_interceptor;
  next();
});

app.get('/gandalf', (req, res) => {
    res.render('gandalf')
});

app.get('/colombo', (req, res) => {
    const timeInColombo = Temporal.Now.zonedDateTimeISO('Asia/Colombo').toLocaleString();
    res.render('colombo', { timeInColombo })
});

app.get("/metrics", async (req, res, next) => {
  res.setHeader("Content-type", register.contentType);
  res.send(await register.metrics());
  next();
});

app.listen(80, '0.0.0.0', () => {
  console.log('Server running');
});