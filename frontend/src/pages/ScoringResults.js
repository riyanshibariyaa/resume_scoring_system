import React from 'react';
import { Typography } from '@mui/material';

const ScoringResults = () => {
  return (
    <div>
      <Typography variant="h4">Scoring Results</Typography>
      <Typography variant="body1" sx={{ mt: 2 }}>
        Results will be displayed here after scoring is complete.
      </Typography>
    </div>
  );
};

export default ScoringResults;
