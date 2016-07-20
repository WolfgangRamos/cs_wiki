class MVar<T> {

  T content;
  boolean empty;
  Object r = new Object();
  Object w = new Object();

  public MVar() {
    content = null;
    empty = true;
  }

  public MVar(T o) {
    content = o;
    empty = false;
  }

  public T take() throws InterruptedException {
    synchronized (r) {
      while (empty) { r.wait(); }
      // here empty is false 
      synchronized (w) {
        empty = true;
        w.notify();
        return content;
      }
    }
  }

  public void put(T o) throws InterruptedException {
    synchronized (w) {
      while (!empty) { w.wait(); }
      // here empty is true
      synchronized (r) {
        empty = false;
        r.notify();
        content = o;
      }
    }
  }

  public T read()  throws InterruptedException {
    synchronized (r) {
      while (empty) { r.wait(); }
      // here empty is false 
      synchronized (w) {
        r.notify();
        return content;
      }
    }
  }
}
