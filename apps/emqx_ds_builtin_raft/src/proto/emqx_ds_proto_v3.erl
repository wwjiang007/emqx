%%--------------------------------------------------------------------
%% Copyright (c) 2024 EMQ Technologies Co., Ltd. All Rights Reserved.
%%--------------------------------------------------------------------
-module(emqx_ds_proto_v3).

-behavior(emqx_bpapi).

-include_lib("emqx_utils/include/bpapi.hrl").
%% API:
-export([
    drop_db/2,
    store_batch/5,
    get_streams/5,
    make_iterator/6,
    next/5,
    update_iterator/5,
    add_generation/2,

    %% introduced in v3
    list_generations_with_lifetimes/3,
    drop_generation/4
]).

%% behavior callbacks:
-export([introduced_in/0, deprecated_since/0]).

%%================================================================================
%% API functions
%%================================================================================

-spec drop_db([node()], emqx_ds:db()) ->
    [{ok, ok} | {error, _}].
drop_db(Node, DB) ->
    erpc:multicall(Node, emqx_ds_replication_layer, do_drop_db_v1, [DB]).

-spec get_streams(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds:topic_filter(),
    emqx_ds:time()
) ->
    [{integer(), emqx_ds_storage_layer:stream_v1()}].
get_streams(Node, DB, Shard, TopicFilter, Time) ->
    erpc:call(Node, emqx_ds_replication_layer, do_get_streams_v1, [DB, Shard, TopicFilter, Time]).

-spec make_iterator(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds_storage_layer:stream_v1(),
    emqx_ds:topic_filter(),
    emqx_ds:time()
) ->
    {ok, emqx_ds_storage_layer:iterator()} | {error, _}.
make_iterator(Node, DB, Shard, Stream, TopicFilter, StartTime) ->
    erpc:call(Node, emqx_ds_replication_layer, do_make_iterator_v1, [
        DB, Shard, Stream, TopicFilter, StartTime
    ]).

-spec next(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds_storage_layer:iterator(),
    pos_integer()
) ->
    {ok, emqx_ds_storage_layer:iterator(), [{emqx_ds:message_key(), [emqx_types:message()]}]}
    | {ok, end_of_stream}
    | {error, _}.
next(Node, DB, Shard, Iter, BatchSize) ->
    emqx_rpc:call(Shard, Node, emqx_ds_replication_layer, do_next_v1, [DB, Shard, Iter, BatchSize]).

-spec store_batch(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds_replication_layer:batch(),
    emqx_ds:message_store_opts()
) ->
    emqx_ds:store_batch_result().
store_batch(Node, DB, Shard, Batch, Options) ->
    emqx_rpc:call(Shard, Node, emqx_ds_replication_layer, do_store_batch_v1, [
        DB, Shard, Batch, Options
    ]).

-spec update_iterator(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds_storage_layer:iterator(),
    emqx_ds:message_key()
) ->
    {ok, emqx_ds_storage_layer:iterator()} | {error, _}.
update_iterator(Node, DB, Shard, OldIter, DSKey) ->
    erpc:call(Node, emqx_ds_replication_layer, do_update_iterator_v2, [
        DB, Shard, OldIter, DSKey
    ]).

-spec add_generation([node()], emqx_ds:db()) ->
    [{ok, ok} | {error, _}].
add_generation(Node, DB) ->
    erpc:multicall(Node, emqx_ds_replication_layer, do_add_generation_v2, [DB]).

%%--------------------------------------------------------------------------------
%% Introduced in V3
%%--------------------------------------------------------------------------------

-spec list_generations_with_lifetimes(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id()
) ->
    #{
        emqx_ds:ds_specific_generation_rank() => emqx_ds:generation_info()
    }.
list_generations_with_lifetimes(Node, DB, Shard) ->
    erpc:call(Node, emqx_ds_replication_layer, do_list_generations_with_lifetimes_v3, [DB, Shard]).

-spec drop_generation(
    node(),
    emqx_ds:db(),
    emqx_ds_replication_layer:shard_id(),
    emqx_ds_storage_layer:gen_id()
) ->
    ok | {error, _}.
drop_generation(Node, DB, Shard, GenId) ->
    erpc:call(Node, emqx_ds_replication_layer, do_drop_generation_v3, [DB, Shard, GenId]).

%%================================================================================
%% behavior callbacks
%%================================================================================

introduced_in() ->
    "5.5.0".

deprecated_since() ->
    "5.5.1".
