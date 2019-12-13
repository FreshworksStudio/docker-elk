# Elastic stack (ELK) on Docker with Nginx

Run the latest version of the [Elastic stack][elk-stack] with Docker and Docker Compose.

It gives you the ability to analyze any data set by using the searching/aggregation capabilities of Elasticsearch and
the visualization power of Kibana.

You can also get auto-provisioned and auto renewed SSL certs through Letsencrypt.

Based on the official Docker images from Elastic:

* [Elasticsearch](https://github.com/elastic/elasticsearch/tree/master/distribution/docker)
* [Logstash](https://github.com/elastic/logstash/tree/master/docker)
* [Kibana](https://github.com/elastic/kibana/tree/master/src/dev/build/tasks/os_packages/docker_generator)

Nginx reverse proxy image and letsencrypt auto renewal image from:
* [Nginx + Letsencrypt](https://github.com/linuxserver/docker-letsencrypt)


This repo is a stripped down fork from [Docker ELK](https://github.com/deviantony/docker-elk).

Some documentation is duplicated but if you are using this for the first time, it is recommended to checkout the original repo for a in-depth tour of the stack.

## Requirements

### Host setup

Make sure to have atleast 2 Gbs of RAM for this stack to run properly.

By default, the stack exposes the following ports on the host:
* 8080: Nginx reverse proxy for Logstash HTTP input
* 5601: Nginx reverse proxy for Kibana
* 80 and 443: Nginx HTTP/HTTPS port for SSL validation

All the routes are reverse proxied through Nginx to ensure secure communication over HTTPS.

## Usage

### Bringing up the stack

Clone this repository, then start the stack using Docker Compose:

```console
$ make app
```

You can also run all services in the background (detached mode) by adding the `-d` flag to the above command.

> :information_source: You must run `make build` first whenever you switch branch or update a base image.

### Cleanup

Elasticsearch data is persisted inside a volume by default.

In order to entirely shutdown the stack and remove all persisted data, use the following Docker Compose command:

```console
$ make clean
```

### Environment configurable events

The docker-compose expects a `.env` file to be present in root directory.
Although the docker-compose will work without it, it's heavily recommended to change the values on a remote server.

There is a `.env.example` file that shows how the `.env` should look like.
When you copy the code on the remote server, make sure to update the .env with newer values.

The values in .env are as follows :

```
ELK_VERSION=7.5.0 (Version of ELK to be installed.)

ELASTIC_PASSWORD : Password for the elastic user on elasticsearch

KIBANA_USER : Username used by Kibana to connect to elasticsearch
KIBANA_PASSWORD : Password for the kibana user generated by elasticsearch

LOGSTASH_USER : Username used by Kibana to connect to elasticsearch
LOGSTASH_PASSWORD : Password for the logstash_system user generated by elasticsearch

LOGSTASH_HTTP_USERNAME : Username for the HTTP input plugin used by Logstash
LOGSTASH_HTTP_PASSWORD : Password for the HTTP input plugin used by Logstash

DOMAIN_NAME : Domain where the ELK stack will be hosted

SUBDOMAIN_LIST : Subdomain where the ELK stack is accessed for e.g. elk.th, www, elk, etc.

STAGING : Generate letsencrypt SSL certificate to be either staging or production kind
```

> :information_source: The staging cert on letsencrypt will not be trusted by browsers but has higher rate limits for
subsequent generations. Setting STAGING=false will generate a HTTPS certificate trusted by browsers but will be rate limited, so be sure to only run it on production servers.

## First time setup

> :information_source: This section is only relevant if you're starting from scratch with this repo.

### Setting up user authentication

The stack is pre-configured with the following **privileged** bootstrap user:

* user: *elastic*
* password: *changeme*

Although all stack components work out-of-the-box with this user, we strongly recommend using the unprivileged [built-in
users][builtin-users] instead for increased security.

1. Initialize passwords for built-in users

```console
$ docker-compose exec -T elasticsearch bin/elasticsearch-setup-passwords auto --batch
```

Passwords for all 6 built-in users will be randomly generated. Take note of them.

2. Update the bootstrap password

Update the `ELASTIC_PASSWORD` environment variable in the .env with the new value.
The initial value was only used to initialize the keystore during the initial startup of Elasticsearch.

3. Replace usernames and passwords in configuration files

Update the `KIBANA_USER`, `KIBANA_PASSWORD`, `LOGSTASH_USER`, and `LOGSTASH_PASSWORD` from values in Step 1.

4. Restart the stack.

```console
$ make restart
```

### Logstash index pattern creation

Currently logstash indexes are created as follows :
`foundry-api-ENVIRONMENT-YEAR.MONTH` e.g. foundry-api-staging-2019.12

As more pipelines are added, it is recommended to follow similar naming patterns for index creation.

## Configuration

> :information_source: Configuration is not dynamically reloaded, you will need to restart individual components after
any configuration change.

### How to configure Elasticsearch

The Elasticsearch configuration is stored in [`elasticsearch/config/elasticsearch.yml`][config-es].

You can also specify the options you want to override by setting environment variables inside the Compose file:

```yml
elasticsearch:

  environment:
    network.host: _non_loopback_
    cluster.name: my-cluster
```

Please refer to the following documentation page for more details about how to configure Elasticsearch inside Docker
containers: [Install Elasticsearch with Docker][es-docker].

### How to configure Kibana

The Kibana default configuration is stored in [`kibana/config/kibana.yml`][config-kbn].

It is also possible to map the entire `config` directory instead of a single file.

Please refer to the following documentation page for more details about how to configure Kibana inside Docker
containers: [Running Kibana on Docker][kbn-docker].

### How to configure Logstash

The Logstash configuration is stored in [`logstash/config/logstash.yml`][config-ls].

It is also possible to map the entire `config` directory instead of a single file, however you must be aware that
Logstash will be expecting a [`log4j2.properties`][log4j-props] file for its own logging.

Please refer to the following documentation page for more details about how to configure Logstash inside Docker
containers: [Configuring Logstash for Docker][ls-docker].

### How to enable/disable paid features

Switch the value of Elasticsearch's `xpack.license.self_generated.type` option to:
- `trial` for paid features (This will start your elastic trial, use Kibana UI to add the paid license information.)
- `basic` for free never expiring license. (default)


[elk-stack]: https://www.elastic.co/elk-stack
[stack-features]: https://www.elastic.co/products/stack
[paid-features]: https://www.elastic.co/subscriptions
[trial-license]: https://www.elastic.co/guide/en/elasticsearch/reference/current/license-settings.html

[booststap-checks]: https://www.elastic.co/guide/en/elasticsearch/reference/current/bootstrap-checks.html
[es-sys-config]: https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html

[win-shareddrives]: https://docs.docker.com/docker-for-windows/#shared-drives
[mac-mounts]: https://docs.docker.com/docker-for-mac/osxfs/

[builtin-users]: https://www.elastic.co/guide/en/x-pack/current/setting-up-authentication.html#built-in-users
[ls-security]: https://www.elastic.co/guide/en/logstash/current/ls-security.html
[sec-tutorial]: https://www.elastic.co/guide/en/elastic-stack-overview/current/security-getting-started.html

[connect-kibana]: https://www.elastic.co/guide/en/kibana/current/connect-to-elasticsearch.html

[config-es]: ./elasticsearch/config/elasticsearch.yml
[config-kbn]: ./kibana/config/kibana.yml
[config-ls]: ./logstash/config/logstash.yml

[es-docker]: https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
[kbn-docker]: https://www.elastic.co/guide/en/kibana/current/docker.html
[ls-docker]: https://www.elastic.co/guide/en/logstash/current/docker-config.html

[log4j-props]: https://github.com/elastic/logstash/tree/7.3/docker/data/logstash/config


