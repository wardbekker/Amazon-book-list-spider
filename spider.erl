-module(spider).
-export([run/0, get_page/1, get_books/1, get_demo_page/0, get_publication_date/1, save_books/2]).
-define(AMAZONURL, "http://www.amazon.com/s?ie=UTF8&rh=n%3A4052").
-define(USERAGENT, "Googlebot/2.1 (+http://www.googlebot.com/bot.html)").
-define(OUTPUTFILE, "/tmp/out.txt").

run() ->
    IoDevice = file:open(?OUTPUTFILE, [append]),
    lists:foreach( fun(PageNr) -> save_books( get_books( get_demo_page() ), IoDevice ) end, lists:seq(1, 20, 1) ),
    file:close(IoDevice).

save_books(BookList, IoDevice) ->
    file:write(IoDevice, "TEST\n").

get_books(PageBody) ->
    Tokens = mochiweb_html:parse( PageBody ),
    Titles = mochiweb_xpath:execute("//div[@class='productTitle']/a/text()", Tokens),
    Bindings = mochiweb_xpath:execute("//div[@class='productTitle']/span[@class='binding']/text()", Tokens),
    PublicationDates = lists:map(fun get_publication_date/1, Bindings),
    lists:zip( Titles, PublicationDates).
					 

get_publication_date(BindingToken) ->
    {match, Matches} = re:run(BindingToken, "(\\w{3,4}).*?(\\d{4})", [{capture, all_but_first, binary}]),
    Matches.

get_page(PageNr) ->
    inets:start(),
    Url = lists:concat([?AMAZONURL, "&page=", PageNr]),
    case httpc:request(get,  {Url, [{"User-Agent", ?USERAGENT}]}, [], []) of
	{ok, {{_Version, 200, _ReasonPhrase}, _Headers, Body}} -> Body;
	{error, Reason} -> erlang:error("got " ++ Reason)
    end.
    
get_demo_page() ->
    readlines("test.txt").

readlines(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    get_all_lines(Device, []).

get_all_lines(Device, Accum) ->
    case io:get_line(Device, "") of
        eof  -> file:close(Device), Accum;
        Line -> get_all_lines(Device, Accum ++ [Line])
    end.
