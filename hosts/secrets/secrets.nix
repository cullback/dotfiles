let
  atlantix = "age103juc77qrmesvzr5dclunlaw37caml8qddfd3xsj2vr3hcn8newq0ypv9e";
  kraken = "age167hfx7uyyaurglgqs67z0k8gddcw2njxa5v9usvns34fwqj004pqr7c6pq";
in
{
  "wg-privkey.age".publicKeys = [ atlantix ];
  "wg-privkey-kraken.age".publicKeys = [ kraken ];
}
