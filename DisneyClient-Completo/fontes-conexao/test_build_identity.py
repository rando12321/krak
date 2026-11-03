# Python / test_build_identity.py / Python 3.11 / reject silently reusing a different running backend
from pathlib import Path
import importlib.util,tempfile,json,os,unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('guard_launcher',str(Path(__file__).resolve().parents[1]/'iniciar_client.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Tests(unittest.TestCase):
 def test_wrong_backend_is_rejected_before_starting_or_opening_browser(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);client=root/'DisneyClient';parser=root/'DisneyParser';client.mkdir();parser.mkdir()
   (client/'.env').write_text('');(client/'BUILD-ID.txt').write_text('sdds-connection-v1');(parser/'tokens.json').write_text(json.dumps(['test-token']))
   with patch.multiple(m,CLIENT=client,PARSER=parser),patch.dict(os.environ,{'TFM_PARSER_API_TOKEN':'','SERVER_PORT':'8080','CLIENT_PARSER_PORT':'8090'}),patch.object(m,'http_ok',return_value=True),patch.object(m,'http_data',return_value={'build_id':'old'}),patch.object(m.subprocess,'Popen',side_effect=AssertionError('must not launch')),patch.object(m.webbrowser,'open',side_effect=AssertionError('must not open')):
    with self.assertRaisesRegex(RuntimeError,'Outra versao'):m.run()
if __name__=='__main__':unittest.main()
