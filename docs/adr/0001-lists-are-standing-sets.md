# Lists are standing sets, not per-trip baskets

> **Restated by [ADR-0010](0010-a-list-item-has-one-status.md):** the promise is unchanged, and its verbs are now Status words — Check, Buy, Need — instead of check/uncheck.

A List is a durable collection of consumables you buy over and over, so a List Item is never destroyed by buying it: checking marks it wanted for the next shop, and clearing the Basket records a Purchase and unchecks. The obvious alternative — a basket you fill, buy, and throw away — was rejected because the whole product promise ("lists that keep up with you", items "frequently unchecked as they are needed again") depends on the same Items surviving every shop.
