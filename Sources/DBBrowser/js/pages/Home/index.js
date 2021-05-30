import _ from 'lodash';
import React from 'react';
import { Button, View, TextInput, Text, ScrollView, StyleSheet } from 'react-native';
import { withRouter } from 'react-router';
import { EJSON } from 'bson';
import CodeMirror from 'react-codemirror';
import Url from 'url';

import RoundButton from '../../components/RoundButton';
import ResultTable from './ResultTable';
import storage from '../../utils/storage';

import { withDatabase } from '../../utils/database';

class Home extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      isConnected: false,
      autoConnect: false,
      connectionStr: '',
      command: '',
      result: '',
    };
  }

  componentDidMount() {

    this.autoConnect();

    const database = this.props.database;
  
    database.addListener('WEBSOCKET_DID_OPENED', () => this.state.autoConnect && this.connect());
    database.addListener('WEBSOCKET_DID_CLOSED', () => this.setState({ isConnected: false }));
  }

  async autoConnect() {

    const connectionStr = storage.getItem('connectionStr');
    const isConnected = storage.getItem('isConnected');

    if (!_.isEmpty(connectionStr)) {
      this.setState({ connectionStr, autoConnect: true }, isConnected ? () => this.connect() : null);
    }
  }

  async connect() {
    
    const database = this.props.database;
  
    try {
      
      if (this.state.isConnected) {
        return;
      }

      await database.connect(this.state.connectionStr);

      this.setState({ isConnected: true, autoConnect: false });

      storage.setItem('connectionStr', this.state.connectionStr);
      storage.setItem('isConnected', true);

    } catch (e) {

      console.log(e);
    }
  }

  async runCommand() {

    try {

      const database = this.props.database;

      let result;
  
      const url = Url.parse(this.state.connectionStr);

      if (url.protocol == 'mongodb:') {
        
        const command = EJSON.parse(this.state.command);

        result = await database.runMongoCommand(command);

      } else {

        result = await database.runSQLCommand(this.state.command);
      }

      this.setState({ result });
      
    } catch (e) {
      console.log(e);
    }
  }

  renderDashboard() {

    const url = Url.parse(this.state.connectionStr);

    let mode = null;

    switch (url.protocol) {
      case 'mysql:': 
        mode = 'text/x-mysql';
        break;
      case 'postgres:': 
        mode = 'text/x-pgsql';
        break;
      case 'mongodb:': 
        mode = 'application/x-json';
        break;
      default: break;
    }

    return <View style={{ flex: 1 }}>
      <View style={{ flexDirection: 'row' }}>
        <Button title='Run' onPress={() => this.runCommand()} />
      </View>
      <CodeMirror
      value={this.state.command}
      onChange={(command) => this.setState({ command })}
      options={{ 
        mode: mode,
        lineNumbers: true,
      }} />
      {!_.isEmpty(this.state.result) && <ResultTable 
        style={{ flex: 1 }} 
        data={this.state.result} />}
    </View>;
  }

  setConnectionStr(connectionStr) {

    this.setState({ connectionStr, autoConnect: false });

    storage.setItem('connectionStr', connectionStr);
  }

  renderLoginPanel() {

    const url = Url.parse(this.state.connectionStr);

    return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <View style={{
        width: 512,
        padding: 16,
			  borderRadius: 16,
			  overflow: 'hidden',
			  alignItems: 'stretch',
			  justifyContent: 'center',
        backgroundColor: 'white',
      }}>

      <Text style={{
        fontSize: 12,
      }}>Connection String</Text>
      <TextInput
        style={{ 
          borderBottomWidth: StyleSheet.hairlineWidth, 
          borderBottomColor: 'black',
          marginTop: 8,
        }}
        onChangeText={(connectionStr) => this.setConnectionStr(connectionStr)}
        value={this.state.connectionStr} />

      <Text style={{
        fontSize: 12,
        marginTop: 16,
      }}>Host</Text>
      <TextInput
        style={{ 
          borderBottomWidth: StyleSheet.hairlineWidth, 
          borderBottomColor: 'black',
          marginTop: 8,
        }}
        value={url.protocol && url.host ? url.protocol+'//'+url.host : ''} />

      <Text style={{
        fontSize: 12,
        marginTop: 16,
      }}>Auth</Text>
      <TextInput
        style={{ 
          borderBottomWidth: StyleSheet.hairlineWidth, 
          borderBottomColor: 'black',
          marginTop: 8,
        }}
        value={url.auth ?? ''} />

      <Text style={{
        fontSize: 12,
        marginTop: 16,
      }}>Database</Text>
      <TextInput
        style={{ 
          borderBottomWidth: StyleSheet.hairlineWidth, 
          borderBottomColor: 'black',
          marginTop: 8,
        }}
        value={url.pathname?.split('/')[1] ?? ''} />

      <RoundButton
        style={{
          marginTop: 16,
          alignSelf: 'center',
        }}
        title='Connect'
        onPress={() => this.connect()} />
      </View>
    </View>;
  }

  renderSideMenu() {

    return <ScrollView>
    </ScrollView>;
  }
  
  render() {

    return <View style={{ 
      flex: 1, 
      flexDirection: 'row', 
      alignItems: 'stretch',
      background: 'Snow',
    }}>
      <View style={{ width: 240, background: 'DarkSlateGray' }}>{this.renderSideMenu()}</View>
      <View style={{ flex: 1 }}>{this.state.isConnected ? this.renderDashboard() : this.renderLoginPanel()}</View>
    </View>;
  }
}

export default withRouter(withDatabase(Home));