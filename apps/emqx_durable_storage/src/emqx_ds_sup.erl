%%--------------------------------------------------------------------
%% Copyright (c) 2022-2024 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------
-module(emqx_ds_sup).

-behaviour(supervisor).

%% API:
-export([start_link/0]).
-export([register_db/2, unregister_db/1, which_dbs/0]).

%% behaviour callbacks:
-export([init/1]).

%%================================================================================
%% Type declarations
%%================================================================================

-define(SUP, ?MODULE).
-define(TAB, ?MODULE).

%%================================================================================
%% API functions
%%================================================================================

-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?SUP}, ?MODULE, top).

register_db(DB, Backend) ->
    ets:insert(?TAB, {DB, Backend}),
    ok.

unregister_db(DB) ->
    ets:delete(?TAB, DB),
    ok.

which_dbs() ->
    ets:tab2list(?TAB).

%%================================================================================
%% behaviour callbacks
%%================================================================================

init(top) ->
    _ = ets:new(?TAB, [public, set, named_table]),
    Children = [emqx_ds_builtin_metrics:child_spec()],
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 1
    },
    {ok, {SupFlags, Children}}.

%%================================================================================
%% Internal functions
%%================================================================================
