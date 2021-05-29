import _ from 'lodash';
import React from 'react';
import { Button, View, TextInput, Text, ScrollView, StyleSheet } from 'react-native';
import ReactDataSheet from 'react-datasheet';
import { withRouter } from 'react-router';
import { EJSON } from 'bson';
import Url from 'url';

import RoundButton from '../components/RoundButton';

import { withDatabase } from '../utils/database';

class ValueViewer extends React.PureComponent {

  render() {
    
    const { value } = this.props.value;
    
    if (_.isString(value)) {
      return <Text>{value}</Text>;
    }
    
    return <Text>{EJSON.stringify(value)}</Text>;
  }
}

class ResultTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      style: 'table',
    };
  }

  renderBody() {
    
    if (!_.isArray(this.props.data)) {
      return <Text>{EJSON.stringify(this.props.data, null, 4)}</Text>;
    }

    switch (this.state.style) {

      case 'table':

        const columns = this.props.data.reduce((result, x) => _.uniq(result.concat(Object.keys(x))), []);
        const grid = this.props.data.map(x => columns.map(c => { return { value: x[c] } }));

        return <ReactDataSheet
          data={grid}
          sheetRenderer={props => (
            <table className={props.className}>
                <thead>
                    <tr>
                      {columns.map(col => (<th><Text>{col}</Text></th>))}
                    </tr>
                </thead>
                <tbody>
                    {props.children}
                </tbody>
            </table>
          )}
          valueViewer={ValueViewer}
          valueRenderer={x => x} />;

      case 'raw':
        return <Text>{EJSON.stringify(this.props.data, null, 4)}</Text>;
    }
  }

  render() {
    return <ScrollView>
    {this.renderBody()}
    </ScrollView>;
  }
}

class Home extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      isConnected: false,
      connectionStr: '',
      command: '',
      result: '',
    };
  }

  async connect() {
    
    try {

      const database = this.props.database;
  
      await database.connect(this.state.connectionStr);

      this.setState({ isConnected: true });

    } catch (e) {
      console.log(e);
    }
  }

  async runCommand() {

    try {

      const database = this.props.database;

      let result;
  
      if (this.state.connectionStr.startsWith('mongodb://')) {
        
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
    
    return <View style={{ flex: 1 }}>
      <TextInput
      multiline
      onChangeText={(command) => this.setState({ command })}
      value={this.state.command} />
      <Button title='Run' onPress={() => this.runCommand()} />
      <ScrollView style={{ flex: 1 }}>
      {!_.isEmpty(this.state.result) && <ResultTable data={this.state.result} />}
      </ScrollView>
    </View>;
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
        onChangeText={(connectionStr) => this.setState({ connectionStr })}
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
        value={url.auth} />

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
        value={url.pathname?.split('/')[1]} />

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