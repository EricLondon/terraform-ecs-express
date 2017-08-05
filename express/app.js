const express = require('express')
const app = express()
const app_port = 80

const AWS = require('aws-sdk')
const s3 = new AWS.S3()
const s3_bucket = process.env.S3_DATA_BUCKET
const s3_put_params = {
  Body: (new Date()).toISOString(),
  Bucket: s3_bucket,
  Key: 'app_start.txt'
}
s3.putObject(s3_put_params, function(err, data){
  if (err) console.log(err);
  else console.log(data);
})
const s3_get_params = {
  Bucket: s3_bucket,
  Key: 'app_start.txt'
}

app.get('/', function (req, res) {
  s3.getObject(s3_get_params, function(err, data){
    if (err) res.status(err.statusCode).send(err.message)
    else res.send(data.Body.toString())
  })
})

app.listen(app_port, function () {
  console.log('App starting on port: ' + app_port)
})
