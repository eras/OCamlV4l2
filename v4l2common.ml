type array_frame = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type rgb_array_frame = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type config = {
  width		: int;
  height	: int;
}

type frame = < 
  raw : string;
  rgb : string;
  raw_ba : array_frame;
  rgb_ba : rgb_array_frame;
>
