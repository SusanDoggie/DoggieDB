import _ from 'lodash';
import React from 'react';
import { Button, View, TextInput, Text, ScrollView, StyleSheet } from 'react-native';
import { withRouter } from "react-router";
import { EJSON } from 'bson';

import { withDatabase } from '../utils/database';

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

      this.setState({ result: EJSON.stringify(result, null, 4) });
      
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
      <Text>{this.state.result}</Text>
      </ScrollView>
    </View>;
  }
  
  renderLoginPanel() {

    return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <View style={{  }}>
      <Text>Connection String</Text>
      <TextInput
        style={{ 
          borderBottomWidth: StyleSheet.hairlineWidth, 
          borderBottomColor: 'black',
          marginTop: 8,
        }}
        onChangeText={(connectionStr) => this.setState({ connectionStr })}
        value={this.state.connectionStr} />
      <Button
        style={{
          marginTop: 8,
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
    }}>
      <View style={{ width: 240, background: 'DarkSlateBlue' }}>{this.renderSideMenu()}</View>
      <View style={{ flex: 1 }}>{this.state.isConnected ? this.renderDashboard() : this.renderLoginPanel()}</View>
    </View>;
  }
}

export default withRouter(withDatabase(Home));