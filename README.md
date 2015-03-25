[![Build Status](https://travis-ci.org/sul-dlss/triannon-client.svg?branch=master)](https://travis-ci.org/sul-dlss/triannon-client) [![Coverage Status](https://coveralls.io/repos/sul-dlss/triannon-client/badge.png)](https://coveralls.io/r/sul-dlss/triannon-client) [![Dependency Status](https://gemnasium.com/sul-dlss/triannon-client.svg)](https://gemnasium.com/sul-dlss/triannon-client) [![Gem Version](https://badge.fury.io/rb/triannon-client.svg)](http://badge.fury.io/rb/triannon-client)

# Triannon Client

A client for the triannon service, see also
- https://github.com/sul-dlss/triannon
- https://github.com/sul-dlss/triannon-service


## Installation into ruby projects

```ruby
gem 'triannon-client'
```

Then execute:

```console
bundle
```


## Using the client

### Configuration

Edit a `.env` file to configure the triannon server address etc.
(see .env_example); or use a configure block, e.g.

```ruby
require 'triannon-client'
::TriannonClient.configure do |config|
  config.debug = true
  config.host = 'http://triannon.example.org:8080'
  config.user = 'authUser'
  config.pass = 'secret'
end
```

### Get a client instance

```ruby
tc = TriannonClient::TriannonClient.new
```

### Get a list of annotations

```ruby
# return an RDF::Graph
graph = tc.get_annoations
```

### Get a particular annotation

```ruby
# the default response is an open annotation in an RDF::Graph
oa_anno = tc.get_annotation(id)
```

For specific response formats, specify an HTTP `Accept` header, e.g.

```ruby
# explicitly request jsonld with an open annotation or a IIIF context
anno_oa   = tc.get_annotation(id, `application/ld+json; profile="http://www.w3.org/ns/oa-context-20130208.json"`)
anno_iiif = tc.get_annotation(id, `application/ld+json; profile="http://iiif.io/api/presentation/2/context.json"`)
# convenience methods to do the above
anno_oa   = tc.get_oa_annotation(id)
anno_iiif = tc.get_iiif_annotation(id)
```

### Create an annotation

```ruby
tc.post_annotation(open_annotation_jsonld)
```

### Delete an annotation

#### TODO


## Development

Clone and install:

```console
./bin/setup.sh
```

Run tests:

```console
./bin/test.sh
```

