module MVarSTM (newEmptyMVar, newMVar, takeMVar, putMVar, tryTake,
                tryPut, overwrite, readMVar, swap, MVar) where

import Control.Concurrent.STM

type MVar a = TVar (Maybe a)

newEmptyMVar :: STM (MVar a)
newEmptyMVar = newTVar Nothing

newMVar :: a -> STM (MVar a)
newMVar v = do
  m <- newEmptyMVar
  putMVar m v
  return m

takeMVar :: MVar a -> STM a
takeMVar m = do
  mv <- readTVar m
  case mv of
    Nothing -> retry
    Just v  -> do writeTVar m Nothing
                  return v

putMVar :: MVar a -> a -> STM ()
putMVar m v = do
  mv <- readTVar m
  case mv of
    Just _  -> retry
    Nothing -> writeTVar m (Just v)

tryTake :: MVar a -> STM (Maybe a)
tryTake m = do
    v <- takeMVar m
    return (Just v)
  `orElse`
    return Nothing  

tryPut :: MVar a -> a -> STM Bool
tryPut m v = do
    putMVar m v
    return True
  `orElse`
    return False

readMVar :: MVar a -> STM a
readMVar m = do
  v <- takeMVar m
  putMVar m v
  return v 

swap :: MVar a -> a -> STM a
swap m v = do
  v' <- takeMVar m
  putMVar m v
  return v'

overwrite :: MVar a -> a -> STM ()
overwrite m v = do -- writeTVar m (Just v)
  tryTake m
  putMVar m v


