%% @doc Main module of the eradius application.
-module(eradius).
-export([load_tables/1, load_tables/2,
         modules_ready/1, modules_ready/2,
         statistics/1]).

-behaviour(application).
-export([start/2, stop/1, config_change/3]).

%% internal use

-include("eradius_lib.hrl").

%% @doc Load RADIUS dictionaries from the default directory.
-spec load_tables(list(eradius_dict:table_name())) -> ok | {error, {consult, eradius_dict:table_name()}}.
load_tables(Tables) ->
    eradius_dict:load_tables(Tables).

%% @doc Load RADIUS dictionaries from a certain directory.
-spec load_tables(file:filename(), list(eradius_dict:table_name())) -> ok | {error, {consult, eradius_dict:table_name()}}.
load_tables(Dir, Tables) ->
    eradius_dict:load_tables(Dir, Tables).

%% @equiv modules_ready(self(), Modules)
modules_ready(Modules) ->
    eradius_node_mon:modules_ready(self(), Modules).

%% @doc Announce request handler module availability.
%%    Applications need to call this function (usually from their application master)
%%    in order to make their modules (which should implement the {@link eradius_server} behaviour)
%%    available for processing. The modules will be revoked when the given Pid goes down.
modules_ready(Pid, Modules) ->
    eradius_node_mon:modules_ready(Pid, Modules).

%% @doc manipulate server statistics
%%    * reset: reset all counters to zero
%%    * pull:  read counters and reset to zero
%%    * read:  read counters
statistics(reset) ->
    eradius_counter_aggregator:reset();
statistics(pull) ->
    eradius_counter_aggregator:pull();
statistics(read) ->
    eradius_counter_aggregator:read().


%% ----------------------------------------------------------------------------------------------------
%% -- application callbacks

%% @private
start(_StartType, _StartArgs) ->
    eradius_sup:start_link().

%% @private
stop(_State) ->
    ok.

%% @private
config_change(Added, Changed, Removed) ->
    lists:foreach(fun do_config_change/1, Added),
    lists:foreach(fun do_config_change/1, Changed),
    Keys = [K || {K, _} <- Added ++ Changed] ++ Removed,
    (lists:member(logging, Keys) or lists:member(logfile, Keys))
        andalso eradius_log:reconfigure(),
    eradius_client:reconfigure().

do_config_change({tables, NewTables}) ->
    eradius_dict:load_tables(NewTables);
do_config_change({servers, _}) ->
    eradius_server_mon:reconfigure();
do_config_change({_, _}) ->
    ok.
