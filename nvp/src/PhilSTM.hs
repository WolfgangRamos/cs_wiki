import Control.Concurrent
import Control.Concurrent.STM

type Stick = TVar Bool

newStick :: IO Stick
newStick = atomically (newTVar True)

takeStick :: Stick -> STM ()
takeStick s = do
  available <- readTVar s
  if available then
    writeTVar s False
  else
    retry

putStick :: Stick -> STM ()
putStick s = writeTVar s True

main :: IO ()
main = do
  s1 <- newStick
  s2 <- newStick
  s3 <- newStick
  s4 <- newStick
  s5 <- newStick
  forkIO $ phil 1 s1 s2
  forkIO $ phil 2 s2 s3
  forkIO $ phil 3 s3 s4
  forkIO $ phil 4 s4 s5
  getLine
  forkIO $ phil 5 s5 s1
  getLine
  return ()
phil :: Int -> Stick -> Stick -> IO ()
phil n sl sr = do
  putStrLn (show n++" is thinking") 
  atomically $ do takeStick sl
                  putStick sl
                  takeStick sl
                  takeStick sr
  putStrLn (show n++" is eating") 
  atomically $ putStick sr
  atomically $ putStick sl
  phil n sl sr

