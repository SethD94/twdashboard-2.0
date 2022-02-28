const express = require('express');
const Cache = require('ttl-cache');
const cors = require('cors');
const { Sequelize } = require('sequelize');
const fs = require('fs');
const { report } = require('process');


const init = async () => {
  // instantiate rest app
  let app = express();

  // connect to the sql db
  const sequelize = new Sequelize('nzteam', 'mike.treadgold', 'mtnz99', {
    dialect: 'mysql',
    dialectOptions: {
      host: 'rekall',
      multipleStatements: true
      // Your mysql2 options here
    }
  })
  corsOptions = {
    origin: 'http://localhost:3000',
    optionsSuccessStatus: 200
  };
  app.use(cors(corsOptions));
  try {
    await sequelize.authenticate();
    console.log('Connection has been established successfully.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }

  const cache = new Cache();


  app.get('/TechWriters', async (req, res) => {
    // TODO: DO THIS HERE!
    const sqlScript = fs.readFileSync('../sql_scripts/GetWriters.sql', 'utf8');
    const users = await sequelize.query(sqlScript);
    const userData = JSON.stringify(users);
    return res.json(userData);
  });

  app.get('/TechWriter/:id', async (req, res) => {
    const { params } = req;
    function filterbyID(report) {
      return report.writer_id === params.id;
    }
    const backlogScript = fs.readFileSync('../sql_scripts/BacklogTasks.sql', 'utf8');
    const workDueSoonScript = fs.readFileSync('../sql_scripts/WorkDueSoonTasks.sql', 'utf8');
    const readyReportScript = fs.readFileSync('../sql_scripts/ReadyTasks.sql', 'utf8');
    const workOnTheHorizonScript = fs.readFileSync('../sql_scripts/WorkOnTheHorizon.sql', 'utf8');
    const backlogQueryResponse = await sequelize.query(backlogScript);
    const workDueSoonQueryResponse = await sequelize.query(workDueSoonScript);
    const readyReportQueryResponse = await sequelize.query(readyReportScript);
    const workOnTheHorizonQueryResponse = await sequelize.query(workOnTheHorizonScript);
    const totalBacklogTasks = backlogQueryResponse[0].filter(filterbyID).length;
    const totalWorkDueSoonTasks = workDueSoonQueryResponse[0].filter(filterbyID).length;
    const totalReadyReportTasks = readyReportQueryResponse[0].filter(filterbyID).length;
    const totalWorkOnTheHorizon = workOnTheHorizonQueryResponse[0].filter(filterbyID).length;
    const outputData = {
      backlogTasks: totalBacklogTasks,
      workDueSoonTasks: totalWorkDueSoonTasks,
      readyTasks: totalReadyReportTasks,
      workOnTheHorizonTasks: totalWorkOnTheHorizon
    }

    return res.json(outputData);

  });

  app.get('/Test/', async (req, res) => {
    const sqlScript = fs.readFileSync('../sql_scripts/WorkOnTheHorizon.sql', 'utf8');
    const workOnTheHorizon = await sequelize.query(sqlScript);
    return res.json(workOnTheHorizon[0]);

  });
  app.get('/BacklogTasks/:Id', async (req, res) => {
    const { params } = req;
    let report = cache.get("backlog"); // Get a value
    if (!report) {
      const sqlScript = fs.readFileSync('../sql_scripts/BacklogTasks.sql', 'utf8');
      report = await sequelize.query(sqlScript);
      cache.set("backlog", report);
      cache.ttl("backlog", 600);
      console.log("Cache has been set");
    } else {
      console.log("Accessing result from cache");
    }
    function filterbyID(report) {
      return report.writer_id === params.Id;
    }
    const filteredReport = report[0].filter(filterbyID)
    return res.json(filteredReport);

  });

  app.get('/WorkDueSoonTasks/:Id', async (req, res) => {
    const { params } = req;
    let report = cache.get("workDueSoon"); // Get a value
    if (!report) {
      const sqlScript = fs.readFileSync('../sql_scripts/WorkDueSoonTasks.sql', 'utf8');
      report = await sequelize.query(sqlScript);
      cache.set("workDueSoon", report);
      cache.ttl("workDueSoon", 600);
      console.log("Cache has been set");
    } else {
      console.log("Accessing result from cache");
    }
    function filterbyID(report) {
      return report.writer_id === params.Id;
    }
    const filteredReport = report[0].filter(filterbyID)
    return res.json(filteredReport);

  });

  app.get('/ReadyTasks/:Id', async (req, res) => {
    const { params } = req;
    let report = cache.get("readyTasks"); // Get a value
    if (!report) {
      const sqlScript = fs.readFileSync('../sql_scripts/ReadyTasks.sql', 'utf8');
      report = await sequelize.query(sqlScript);
      cache.set("readyTasks", report);
      cache.ttl("readyTasks", 600);
      console.log("Cache has been set");
    } else {
      console.log("Accessing result from cache");
    }
    function filterbyID(report) {
      return report.writer_id === params.Id;
    }
    const filteredReport = report[0].filter(filterbyID)
    return res.json(filteredReport);

  });


  app.get('/WorkOnTheHorizon/:ID', async (req, res) => {
    const { params } = req;
    const sql_script = fs.readFileSync('../sql_scripts/WorkOnTheHorizon.sql', 'utf8');
    const Report = await sequelize.query(sql_script);
    function filterbyID(report) {
      return report.writer_id === params.ID;
    }
    const filteredReport = Report[0].filter(filterbyID)
    return res.json(filteredReport);

  });


  const PORT = 8000;
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
  });
}

init()
