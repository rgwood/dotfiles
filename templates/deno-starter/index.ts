import { assertEquals } from "https://deno.land/std@0.144.0/testing/asserts.ts";

console.log("Hello World");

Deno.test("foo", () => { assertEquals("bar", "baz");});
