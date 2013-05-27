%%%-------------------------------------------------------------------
%%% File    : herp_sup.erl
%%% Author  : passwd aero <aero@archtop.emea.hpqcorp.net>
%%% Description : 
%%%
%%% Created : 27 May 2013 by passwd aero <aero@archtop.emea.hpqcorp.net>
%%%-------------------------------------------------------------------
-module(herp_sup).

-behaviour(supervisor).
%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% External exports
%%--------------------------------------------------------------------
-export([
         start_link/0
        ]).

%%--------------------------------------------------------------------
%% Internal exports
%%--------------------------------------------------------------------
-export([
         init/1
        ]).

%%--------------------------------------------------------------------
%% Macros
%%--------------------------------------------------------------------
-define(SERVER, ?MODULE).

%%--------------------------------------------------------------------
%% Records
%%--------------------------------------------------------------------

%%====================================================================
%% External functions
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link/0
%% Description: Starts the supervisor
%%--------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Server functions
%%====================================================================
%%--------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}   
%%--------------------------------------------------------------------
init(_Args) ->
    {ok, {{simple_one_for_one, 3, 60}, 
          [{herp_client, {herp_client, start_link, []},
            transient, 5000, worker, [herp_client]}
          ]}}.

%%====================================================================
%% Internal functions
%%====================================================================
