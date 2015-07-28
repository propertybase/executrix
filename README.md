# Executrix

[![Build Status](https://travis-ci.org/propertybase/executrix.png?branch=master)](https://travis-ci.org/propertybase/executrix) [![Coverage Status](https://coveralls.io/repos/propertybase/executrix/badge.png?branch=master)](https://coveralls.io/r/propertybase/executrix) [![Code Climate](https://codeclimate.com/github/propertybase/executrix.png)](https://codeclimate.com/github/propertybase/executrix) [![Dependency Status](https://gemnasium.com/propertybase/executrix.png)](https://gemnasium.com/propertybase/executrix) [![Gem Version](https://badge.fury.io/rb/executrix.png)](http://badge.fury.io/rb/executrix)

**NOTICE:** This gem is deprecated as of July 28th. Please consider using the sucessor of this gem: [bulkforce](https://github.com/propertybase/bulkforce).

**DISCLAIMER**: This gem is a rewrite of the [salesforce_bulk](https://github.com/jorgevaldivia/salesforce_bulk) gem. As the original maintainer didn't respond to my [pull-request](https://github.com/jorgevaldivia/salesforce_bulk/pull/14) I decided to rerelease the gem under different name.

The original Copyright Notice and all the original commit logs have been retained.

## Overview

Executrix is a simple ruby gem for connecting to and using the [Salesforce Bulk API](http://www.salesforce.com/us/developer/docs/api_asynch/index.htm). This gem only supports the functionality provided by the bulk API.

## Installation

~~~ sh
$ sudo gem install executrix
~~~

## How to use

Using this gem is simple and straight forward.

### Initialize

~~~ ruby
require 'executrix'
salesforce = Executrix::Api.new('YOUR_SALESFORCE_USERNAME', 'YOUR_SALESFORCE_PASSWORD+YOUR_SALESFORCE_TOKEN')
~~~

To use sandbox:

~~~ ruby
salesforce = Executrix::Api.new('YOUR_SALESFORCE_SANDBOX_USERNAME', 'YOUR_SALESFORCE_PASSWORD+YOUR_SALESFORCE_SANDBOX_TOKEN', true)
~~~

Note: the second parameter is a combination of your Salesforce token and password. So if your password is xxxx and your token is yyyy, the second parameter will be xxxxyyyy

#### OrgId

After you created the client object you can fetch the OrgId via `org_id`.

This will fetch the 15 digit OrgId.

~~~ ruby
salesforce.org_id # '00D50000000IehZ'
~~~

### Operations

~~~ ruby
# Insert
new_account = {'name' => 'Test Account', 'type' => 'Other'} # Add as many fields per record as needed.
records_to_insert = []
records_to_insert << new_account # You can add as many records as you want here, just keep in mind that Salesforce has governor limits.
result = salesforce.insert('Account', records_to_insert)
puts "reference to the bulk job: #{result.inspect}"
~~~

~~~ ruby
# Update
updated_account = {'name' => 'Test Account -- Updated', 'id' => 'a00A0001009zA2m'} # Nearly identical to an insert, but we need to pass the salesforce id.
records_to_update = []
records_to_update.push(updated_account)
salesforce.update('Account', records_to_update)
~~~

~~~ ruby
# Upsert
upserted_account = {'name' => 'Test Account -- Upserted', 'External_Field_Name' => '123456'} # Fields to be updated. External field must be included
records_to_upsert = []
records_to_upsert.push(upserted_account)
salesforce.upsert('Account', records_to_upsert, 'External_Field_Name') # Note that upsert accepts an extra parameter for the external field name
~~~

~~~ ruby
# Delete
deleted_account = {'id' => 'a00A0001009zA2m'} # We only specify the id of the records to delete
records_to_delete = []
records_to_delete.push(deleted_account)
salesforce.delete('Account', records_to_delete)
~~~

~~~ ruby
# Query
res = salesforce.query('Account', 'select id, name, createddate from Account limit 3') # We just need to pass the sobject name and the query string
puts res.result.records.inspect
~~~

## File Upload

For file uploads, just add a `File` object to the binary columns.
~~~ ruby
attachment = {'ParentId' => '00Kk0001908kqkDEAQ', 'Name' => 'attachment.pdf', 'Body' => File.new('tmp/attachment.pdf')}
records_to_insert = []
records_to_insert << attachment
salesforce.insert('Attachment', records_to_insert)
~~~

### Query status

The above examples all return immediately after sending the data to the Bulk API. If you want to wait, until the batch finished, call the final_status method on the batch-reference.

~~~ ruby
new_account = {'name' => 'Test Account', 'type' => 'Other'} # Add as many fields per record as needed.
records_to_insert = []
records_to_insert << new_account # You can add as many records as you want here, just keep in mind that Salesforce has governor limits.
batch_reference = salesforce.insert('Account', records_to_insert)
results = batch_reference.final_status
puts "the results: #{results.inspect}"
~~~

Additionally you cann pass in a block to query the current state of the batch job:

~~~ ruby
new_account = {'name' => 'Test Account', 'type' => 'Other'} # Add as many fields per record as needed.
records_to_insert = []
records_to_insert << new_account # You can add as many records as you want here, just keep in mind that Salesforce has governor limits.
batch_reference = salesforce.insert('Account', records_to_insert)
results = batch_reference.final_status do |status|
  puts "running: #{status.inspect}"
end
puts "the results: #{results.inspect}"
~~~

The block will yield every 2 seconds, but you can also specify the poll interval:

~~~ ruby
new_account = {'name' => 'Test Account', 'type' => 'Other'} # Add as many fields per record as needed.
records_to_insert = []
records_to_insert << new_account # You can add as many records as you want here, just keep in mind that Salesforce has governor limits.
batch_reference = salesforce.insert('Account', records_to_insert)
poll_interval = 10
results = batch_reference.final_status(poll_interval) do |status|
  puts "running: #{status.inspect}"
end
puts "the results: #{results.inspect}"
~~~

## Copyright

Copyright (c) 2012 Jorge Valdivia.
Copyright (c) 2013 Leif Gensert, [Propertybase GmbH](http://propertybase.com)
