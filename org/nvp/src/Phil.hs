import Control.Concurrent

type Stick = MVar ()

main :: IO ()
main = do
  s1 <- newMVar ()
  s2 <- newMVar ()
  s3 <- newMVar ()
  s4 <- newMVar ()
  s5 <- newMVar ()
  forkIO $ phil 1 s1 s2
  forkIO $ phil 2 s2 s3
  forkIO $ phil 3 s3 s4
  forkIO $ phil 4 s4 s5
  getLine
  phil 5 s5 s1

phil :: Int -> Stick -> Stick -> IO ()
phil n sl sr = do
  putStrLn (show n++" is thinking") 
  takeMVar sl
  takeMVar sr
  putStrLn (show n++" is eating") 
  putMVar sr ()
  putMVar sl ()
  phil n sl sr

