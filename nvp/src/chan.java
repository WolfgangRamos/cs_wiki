package nvp.serie02.aufgabe2;

import nvp.serie01.aufgabe3.MVar;
import java.util.concurrent.Semaphore;

public class Chan<T> {

	private MVar<MVar<ChanElem<T>>> read;
	private MVar<MVar<ChanElem<T>>> write;
	private Semaphore count;

	public Chan() {
		MVar<ChanElem<T>> hole = mkHole();
		read = new MVar<MVar<ChanElem<T>>>(hole);
		write = new MVar<MVar<ChanElem<T>>>(hole);
		count = new Semaphore(0);
	}

	private MVar<ChanElem<T>> mkHole() {
		return new MVar<ChanElem<T>>();
	}

	public T read() throws InterruptedException {
		// stellt sicher, dass Leser auf einerm leeren Channel
		// blockieren ohne den read Pointer zu leeren
		count.acquire(); 
		MVar<ChanElem<T>> rEnd = read.take();
		ChanElem<T> item = rEnd.read();
		read.put(item.getNext());
		return item.getValue();
	}

	public void write(T v) throws InterruptedException {
		MVar<ChanElem<T>> newHole = new MVar<ChanElem<T>>();
		MVar<ChanElem<T>> oldHole = write.take();
		oldHole.put(new ChanElem<T>(v, newHole));
		write.put(newHole);
		count.release(); // new
	}


	public boolean isEmpty() throws InterruptedException {
		// Problem hier:
		// Seien t1,t2 Threads und c ein leerer Chan.
		// Ruft t1 c.read() auf so wird zuerst read.take() ausgeführt bevor t1
		// auf rEnd.read() blockiert da im rEnd kein Element hinterlegt ist
		// (leerer Chan). Ruft t2 nun c.isEmpty() auf so blockiert t2 auf
		// read.take(), da t1 read noch nicht wieder gefüllt hat.
		//
		// D.h. das isEmpty() kann auf leeren Chans blockieren!
		MVar<ChanElem<T>> rEnd = read.take();
		boolean b = rEnd.isEmpty();
		read.put(rEnd);
		return b;
	}

	
	public boolean isEmpty() {
		return count.availablePermits() == 0; // new
	}


	public void unget(T v) throws InterruptedException {
		// Problem hier:
		// Blockiert ein Thread t1 bei einem leeren Chan c in c.read(), so
		// blockiert auch ein Thread t2 bei c.unget(v)
		MVar<ChanElem<T>> rEnd = read.take();
		MVar<ChanElem<T>> newREnd = new MVar<ChanElem<T>>(new ChanElem<T>(v,rEnd));
		read.put(newREnd);
	}

	public void addMultiple(T[] values) throws InterruptedException {
		// Problem hier:
		// Es wird nicht sichergestellt, dass alle Werte des Arrays
		// auch wirklich hintereinander im Channel stehen
		for(int i = 0; i < values.length; i++) {
			write(values[i]);
		}
	}
}

	


	public void unget(T v) throws InterruptedException {
		MVar<ChanElem<T>> rEnd = read.take();
		MVar<ChanElem<T>> newREnd = 
			new MVar<ChanElem<T>>(new ChanElem<T>(v, rEnd));
		read.put(newREnd);
		count.release(); // new
	}
}












































