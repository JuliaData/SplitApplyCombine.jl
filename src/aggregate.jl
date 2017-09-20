

aggregate(op, f, final, v0, iter) = final(mapreduce(op, f, v0, iter))