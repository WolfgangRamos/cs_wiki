import Control.Concurrent

type Account = MVar Int

newAccount :: Int -> IO Account
newAccount amount = do
  newMVar amount

getBalance :: Account -> IO Int
getBalance acc = do
  v <- readMVar acc
  return v

deposit :: Int -> Account -> IO ()
deposit am acc = do
  bal <- takeMVar acc
  putMVar acc (bal + am)

withdraw :: Int -> Account -> IO ()
withdraw am acc = do
  deposit (-am) acc

transfer :: Int -> Account -> Account -> IO ()
transfer am from to = do
  withdraw am from
  deposit am to

transferIfAvailable :: Int -> Account -> Account -> IO Bool
transferIfAvailable am from to = do
  {- Kompositionell, aber falsch
  bal <- getBalance from
  if bal >= am
    then do
      transfer am from to
      return True
    else do
      return False-}

  -- weniger kopositionell, nur korrekte Kontostände sichtbar,
  -- aber mit möglichem Deadlock 
  balFrom <- takeMVar from
  if balFrom > am
    then do
      deposit am to
      putMVar from (balFrom - am)
      return True
    else do
      putMVar from balFrom
      return False






  
