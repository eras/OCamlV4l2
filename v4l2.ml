include V4l2common

open Bigarray

type t'c
type t = {
  t'c			: t'c;
  mutable started	: bool
}

external v4l2_open : string -> int -> int -> t'c = "v4l2_open"

external v4l2_done : t'c -> unit = "v4l2_done"

external v4l2_start : t'c -> unit = "v4l2_start"

external v4l2_stop : t'c -> unit = "v4l2_stop"

external v4l2_get_frame : t'c -> array_frame = "v4l2_get_frame"

external v4l2_decode_mjpeg : array_frame -> rgb_array_frame = "v4l2_decode_mjpeg"

external v4l2_decode_yuv422 : array_frame -> rgb_array_frame = "v4l2_decode_yuv422"

external v4l2_get_format : t'c -> string = "v4l2_get_format"

external v4l2_get_fd : t'c -> Unix.file_descr = "v4l2_get_fd"

let get_fd t = v4l2_get_fd t.t'c

let destruct t =
  if t.started then v4l2_stop t.t'c;
  v4l2_done t.t'c

let init device_name config =
  let t'c = v4l2_open device_name config.width config.height in
  let t = {
    t'c = t'c;
    started = false;
  } in
    Gc.finalise destruct t;
    t

let start t = 
  match t.started with
    | false ->
	v4l2_start t.t'c;
	t.started <- true
    | true ->
	()

let stop t = 
  match t.started with
    | true ->
	v4l2_stop t.t'c;
	t.started <- false
    | false ->
	()

let string_of_bigarray array_frame =
  let len = Array1.dim array_frame in
  let s = String.create len in
    for c = 0 to len - 1 do
      String.set s c (Char.chr array_frame.{c})
    done;
    s

let get_frame t = 
  let rec get_nonzero_frame () =
    let frame = v4l2_get_frame t.t'c in
    let len = Array1.dim frame in
    if len = 0
    then get_nonzero_frame ()
    else frame
  in
  let raw =
    match t.started with
    | false ->
      v4l2_start t.t'c;
      let image = get_nonzero_frame () in
      v4l2_stop t.t'c;
      image
    | true ->
      get_nonzero_frame ()
  in
  let format = v4l2_get_format t.t'c in
  (object (self)
    method raw_ba = raw
    method rgb_ba = 
      match format with
      | "MJPG" -> v4l2_decode_mjpeg raw
      | "YUYV" -> v4l2_decode_yuv422 raw
      | x -> failwith ("invalid format " ^ x)
    method raw = string_of_bigarray self#raw_ba
    method rgb = string_of_bigarray self#rgb_ba
   end)
