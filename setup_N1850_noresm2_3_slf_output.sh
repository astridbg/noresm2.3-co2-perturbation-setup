#!/bin/bash

cur_fld=$(pwd)

nor_repo=$HOME/sources/noresm2.3_slf_out
nor_ver=noresm2_3_alpha03_slf_output

cam_repo=$nor_repo/components/cam
cam_ver=cam_noresm2_3_v1.0.0d_slf_output

casename=N1850_f19_tn14_noresm2_3_slf_output_20250529

#Remove dirs to rerun if previous run failed
rm -r ./$casename
rm -r $USERWORK/archive/$casename
rm -r $USERWORK/noresm/$casename

cd $nor_repo
git fetch --all
git checkout $nor_ver
./manage_externals/checkout_externals

cd $cam_repo
git fetch --all
git checkout $cam_ver

cd $cur_fld

$nor_repo/cime/scripts/create_newcase --case /cluster/projects/nn9600k/astridbg/cases/$casename --compset N1850 --res f19_tn14 --machine betzy --project nn9600k --run-unsupported

cd $casename
echo "CASE CREATED"

# Copy my_chem_mech.in file to case directory
infile_repo=$cur_fld/input/NorESM2.3
cp $infile_repo/my_chem_mech.in .
cp $infile_repo/env_mach_pes.xml .

echo "INPUT FILE ADDED TO CASE DIRECTORY"

./case.setup

./xmlchange --append CAM_CONFIG_OPTS=-cosp

./xmlchange --append CAM_CONFIG_OPTS="--usr_mech_infile /cluster/projects/nn9600k/astridbg/cases/$casename/my_chem_mech.in"

./xmlchange STOP_N=15,STOP_OPTION=nyears

./xmlchange RUN_TYPE=branch

./xmlchange RUN_REFCASE=N1850_f19_tn14_20241127_test16

./xmlchange RUN_REFDATE=1920-01-01

./xmlchange RESUBMIT=9

./xmlchange REST_N=5,REST_OPTION=nyears

./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=FALSE

./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=30:00:00

echo "XML CHANGES DONE"


# Copy restart files

cp /nird/datalake/NS9560K/noresm2.3/cases/N1850_f19_tn14_20241127_test16/rest/1920-01-01-00000/* /cluster/work/users/astridbg/noresm/$casename/run/
gunzip /cluster/work/users/astridbg/noresm/$casename/run/*.gz

echo "RESTART FILES COPIED"

# Update namelists

printf "  
&chem_surfvals_nl
 co2vmr		=    284.32e-6  

&slfsimulator_nl
 slf_isotherms = .true.

&cospsimulator_nl
 docosp         = .true.
 cosp_amwg      = .true.

&sec_ice_nl
 rafsip_on              = .true.

&hetfrz_classnuc_nl
 hetfrz_aer_scalfac             = 1.0D0
 use_hetfrz_classnuc            = .true.

/" >> user_nl_cam

echo "NAMELIST UPDATED"

./case.build


#./case.submit
