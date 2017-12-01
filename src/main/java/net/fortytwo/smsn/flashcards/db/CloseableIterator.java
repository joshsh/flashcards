package net.fortytwo.smsn.flashcards.db;

import java.util.Iterator;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public interface CloseableIterator<T> extends Iterator<T> {
    void close();
}
