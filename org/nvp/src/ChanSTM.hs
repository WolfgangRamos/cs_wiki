module ChanSTM (newChan, writeChan, readChan, isEmpty) where

import MVarSTM
import Control.Concurrent (forkIO)
import Control.Concurrent.STM

data ChanElem a = ChanElem a (MVar (ChanElem a))

data Chan a = Chan (MVar (MVar (ChanElem a))) (MVar (MVar (ChanElem a)))

newChan :: STM (Chan a)
newChan = do
  hole <- newEmptyMVar
  read <- newMVar hole
  write <- newMVar hole
  return (Chan read write)

readChan :: Chan a -> STM a
readChan (Chan read _) = do
  rEnd <- takeMVar read
  ChanElem v next <- takeMVar rEnd
  putMVar read next
  return v

writeChan :: Chan a -> a -> STM ()
writeChan (Chan _ write) v = do
  wEnd <- takeMVar write
  newHole <- newEmptyMVar
  putMVar wEnd (ChanElem v newHole)
  putMVar write newHole

isEmpty :: Chan a -> STM Bool
isEmpty (Chan read write) = do
  rEnd <- readMVar read
  wEnd <- readMVar write
  return (rEnd == wEnd)

chanTest :: IO ()
chanTest = do
  ch <- atomically newChan
  forkIO (do v <- atomically $ readChan ch
             print v)
  getLine
  bool <- atomically $ isEmpty ch
  if bool then
    atomically $ writeChan ch 73
  else
    print 42

