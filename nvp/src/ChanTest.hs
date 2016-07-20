import Control.Concurrent
import Control.Concurrent.Chan

main = do
  ch <- newChan
  forkIO $ do str <- readChan ch
              putStrLn str
  getLine
  b <- isEmptyChan ch
  if b 
    then writeChan ch "Hallo"
    else writeChan ch "Da steht bestimmt gar nichts"

