open Core.Std
open Async.Std
open Opium.Std

let e1 = get "/version" (fun req -> (`String "testing") |> respond')

let e2 = get "/hello/:name" (fun req -> 
  let name = param req "name" in
  `String ("hello " ^ name) |> respond')

let e3 = get "/xxx/:x/:y/?" begin fun req ->
  let x = "x" |> param req |> Int.of_string in
  let y = "y" |> param req |> Int.of_string in
  let sum = Float.of_int (x + y) in
  `Json (Cow.Json.Float sum) |> respond'
end

let e4 = put "/hello/:x/from/:y" begin fun req ->
  let (x,y) = (param req "x", param req "y") in
  let msg = sprintf "Hello %s! from %s." x y in
  `String msg |> respond |> return
end

let set_cookie = get "/set/:key/:value" begin fun req ->
  let (key, value) = (param req "key", param req "value") in
  `String (Printf.sprintf "Set %s to %s" key value)
  |> respond
  |> Cookie.set ~key ~data:value
  |> return
end

let get_cookie = get "/get/:key" begin fun req ->
  Log.Global.info "Getting cookie";
  let key = param req "key" in
  let message = sprintf "Cookie %s doesn't exist" key in
  let value = Option.value_exn ~message (Cookie.get req ~key) in
  `String (sprintf "Cookie %s is: %s" key value) |> respond |> return
end

let all_cookies = get "/cookies" begin fun req ->
  let cookies = req
                |> Cookie.cookies
                |> List.map ~f:(fun (k,v) -> k ^ "=" ^ v)
                |> String.concat ~sep:"\n"
  in
  `String (sprintf "<pre>%s</pre>" cookies) |> respond |> return
end

(* exceptions should be nicely formatted *)
let throws = get "/yyy" (fun req ->
  Log.Global.info "Crashing...";
  failwith "expected failure!")

(* TODO: a static path will not be overriden. bug? *)
let override_static = get "/public/_tags" (fun req ->
  (`String "overriding path") |> respond |> return)

let _ = start
          ~extra_middlewares:[
            Cookie.m;
            Static.m ~local_path:"./" ~uri_prefix:"/public"
          ]
          ([ e1
           ; e2
           ; e3
           ; e4
           ; get_cookie
           ; set_cookie
           ; all_cookies
           ; throws ])
