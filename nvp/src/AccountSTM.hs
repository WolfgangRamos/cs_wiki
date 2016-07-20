import Control.Concurrent
import Control.Concurrent.STM

type Account = TVar Int

newAccount :: Int -> STM Account
newAccount amount = do
  newTVar amount

getBalance :: Account -> STM Int
getBalance acc = do
  v <- readTVar acc
  return v

deposit :: Int -> Account -> STM ()
deposit am acc = do
  bal <- getBalance acc
  writeTVar acc (bal + am)

withdraw :: Int -> Account -> STM ()
withdraw am acc = do
  deposit (-am) acc

transfer :: Int -> Account -> Account -> STM ()
transfer am from to = do
  withdraw am from
  deposit am to

transferIfAvailable :: Int -> Account -> Account -> STM Bool
transferIfAvailable am from to = do
  {- Kompositionell, aber richtig
  bal <- getBalance from
  if bal >= am
    then do
      transfer am from to
      return True
    else do
      return False-}

  -- weniger kompositionell, nur korrekte Kontostände sichtbar,
  -- aber ohne möglichen Deadlock 
  balFrom <- readTVar from
  if balFrom > am
    then do
      deposit am to
      writeTVar from (balFrom - am)
      return True
    else do
      writeTVar from balFrom
      return False

main :: IO ()
main = do
  acc1 <- atomically $ newAccount 100
  acc2 <- atomically $ newAccount 100
  b <- atomically $ transferIfAvailable 150 acc1 acc2
  print b





