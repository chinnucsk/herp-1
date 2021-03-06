Herp
====

HPCloud OpenStack bindings in Erlang
====================================

Currently you can:

Identity
--------

* Login

Compute
-------

* Provision servers
* Delete servers
* List Images you have
* List Flavours available

Block
-----

* Create block storage
* Delete block storage
* List block storage

Object
------

* Upload Files
* Delete Files

CDN
---

* List Containers
* Create Containers
* Enable CDN containers
* Disable CDN containers

By providing a sys.config file you can login via
`herp_identity:login_conf`, otherwise you can provide them directly.

```erlang

{ok, Client} = herp_identity:login(Username, Password, TenantID).
{ok, Client2} = herp_identity:login_conf().
```

Once you have a client, it will be managed by the `herp_sup`
supervisor, restarting your client if you cause it to crash, logging
back in and getting a new AuthToken. This happens entirely
transparently from your perspective.

Since the re-Auth will take place asynchronously there is a
possibility that whilst your token is being revalidated that your
reference will be invalid. This is a minor race condition and is
entirely temporary. Perhaps I will make it block whilst the new token
is being fetched and unblock the callers when it has revalidated. That
is for future versions, though.

Configuration
=============

For some features your sys.config or environment should contain:

```erlang
[
 {herp, [
         {has_proxy, boolean() },
         {proxyaddr, proxy_address::string()},
         {proxyport, proxy_port::integer()},
         {username, username::string()},
         {password, password::string()},
         {tenant_id, tenant_id::string()}
        ]
 }].
```

Building
========

Prerequisites:

* rebar
* relx

```shell
$ git clone https://github.com/AeroNotix/herp.git
$ cd herp
$ make
```

The documentation can be built with:

```shell
$ make docs
```

This will create the `docs/` folder in your current directory.

Listing containers
==================

```erlang

ContainersTop = herp_object:list(Client).
ContainersDetail = herp_object:list(Client, "container").
```

This returns a proplist as such:

```erlang

[[{<<"count">>,13},
  {<<"bytes">>,4904536},
  {<<"name">>,<<"ContainerName">>}],
 [{<<"count">>,0},
  {<<"bytes">>,0},
  {<<"name">>,<<"OtherContainerName">>}],
 [{<<"count">>,11},
  {<<"bytes">>,384012},
  {<<"name">>,<<"Awseum">>}]]
```

Creating Containers
===================

```erlang

ok = herp_object:create_directory(Client, "NewDirectory"),

%% You can also set custom headers on the request.
ok = herp_object:create_directory(Client, "NewDirectory", [{"Header", "Option"}]).
```

Uploading Files
===============

```erlang

ok = herp_object:upload_file(Client, "/path/to/file", "container_name"),

%% Set extra headers.
ok = herp_object:upload_file(Client, "/path/to/file2", "container_name", [{"header", "option"}]),

%% Specify your timeout.
ok = herp_object:upload_file(Client, "/path/to/file2", "container_name", [{"header", "option"}], 5000),
```

Files are md5'd in order to check for end-to-end integrity, they are
also checked for their Content-type when being uploaded.

Provision New Servers
=====================

```erlang

ok = herp_compute:create_server(Client, [{<<"name">>, <<"awesomium">>},
                                          {<<"flavorRef">>, herp_compute:flavour(xsmall)},
                                          {<<"imageRef">>, <<"1359">>}]).
```

Implementation
==============

Herp uses Erlang's amazing Supervision capabilities to provide a
highly-available client.

Here's what happens when you login to the HPCloud:

* Spawn a gen_server specifically for your session.
* This session is then registered with the herp_client_sup, watching
  for failures.
* Login asynchronously to the HPCloud.
* Register the Pid of this gen_server with the herp_refreg module.
* Return a unique refererence.

This ensures that at no point you end up without either a meandering
gen_server and you won't end up without any useful error messages.

Imagine a scenario when your client crashes, a timeout occurs or
you're passed something which you cannot process. It would be
unfortunate for the Pid you received to become invalid.

To get around this herp_refreg is used as a mapping between unique
references and the Pids themselves. A herp_client gen_server is free
to crash and you will never end up with an invalid reference.

Here's a visual representation of the system:

![safe_system](https://raw.github.com/AeroNotix/herp/master/priv/supervision_tree.png)

When a crash occurs and the herp_client is no longer able to continue,
it exits and the system will re-login to the HPCloud:

![restart_system](https://raw.github.com/AeroNotix/herp/master/priv/supervision_tree_restart_pid.png)

As you can see this provides a high-availability client whilst
maintaining a clean API. There is no tracking of AuthTokens,
or client connections or anything like that. You just log in
and work with the API prodvided.
